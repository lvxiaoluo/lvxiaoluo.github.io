
``` java
public class Test{
    private ExecutorService executor = new ThreadPoolExecutor(50, 80,
        10000L, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<>(200),
        new ThreadFactoryBuilder()
                .setNameFormat("attachment-pool-%d")
                .setThreadFactory(r -> {
                    Thread t = new Thread(r);
                    t.setDaemon(true);
                    return t;
                })
                .build(), new ThreadPoolExecutor.CallerRunsPolicy());

/**
     * 下载客户才能附件
     * @param attachmentParam 文件附件参数
     * @param response        返回响应
     */
    public void downCourseAttachment(FileAttachmentParam attachmentParam, HttpServletResponse response) {

        //校验参数是否合法
        validate(attachmentParam);
        long startTime = System.currentTimeMillis();
        log.info("开始下载附件.......time:{}",startTime);
        if (Objects.equals(FileSource.FILE_PLATFORM, attachmentParam.getType())) {
            response.setContentType("application/octet-stream; charset=UTF-8");
            response.setHeader("Content-disposition", "attachment;filename=attachment.zip");
            try {
                ZipOutputStream zouts = new ZipOutputStream(response.getOutputStream());
                List<PlatformFileDto> platformFileDtos = queryPlatFormInfo(attachmentParam.getFileIds());
                log.info("查找数据库附件信息列表.......用时:{}秒",(System.currentTimeMillis()-startTime)/1000);
                List<CompletableFuture<AttachmentFileDto>> futures = platformFileDtos.stream()
                        .map(x->CompletableFuture.supplyAsync(()->requestAttachFile(x),executor)).collect(Collectors.toList());
                log.info("downCourseAttachment---阻塞开始等待结果.....");
                List<AttachmentFileDto> results = futures.parallelStream().map(CompletableFuture::join).collect(Collectors.toList());
                log.info("downCourseAttachment---阻塞结束获取结果.....");
                log.info("从oss获取下载附件列表.......用时:{}秒",(System.currentTimeMillis()-startTime)/1000);
                int index = 0;
                for (AttachmentFileDto fileDto : results) {
                    if (Objects.isNull(fileDto) || Objects.isNull(fileDto.getResource())){
                        return;
                    }
                    // 创建一个ZipEntry
                    ZipEntry entry = new ZipEntry(fileDto.getPlatformFileDto().getName()+index+ Constants.Symbol.PONIT+
                            fileDto.getPlatformFileDto().getExt());
                    // 存储信息到压缩文件
                    InputStream in = fileDto.getResource().getInputStream();
                    zouts.putNextEntry(entry);
                    // 复制字节到压缩文件
                    IOUtils.copy(in, zouts);
                    zouts.closeEntry();
                    in.close();
                    index++;
                }
                zouts.close();
            } catch (Exception e) {
                log.error("downCourseAttachment-下载课程/课时附件失败-fileIds:{}-errMsg:[{}]", attachmentParam.getFileIds(),
                        e.getMessage());
                e.printStackTrace();
                throw new AppBizException("文件下载失败");
            }
        }
        log.info("结束下载附件.....用时:{}秒",(System.currentTimeMillis()-startTime)/1000);

    }


    private AttachmentFileDto requestAttachFile(PlatformFileDto platformFileDto){
        AttachmentFileDto attachmentFileDto = new AttachmentFileDto();
        attachmentFileDto.setPlatformFileDto(platformFileDto);
        ExchangeStrategies strategies = ExchangeStrategies.builder()
                .codecs(configurer -> configurer
                        .defaultCodecs()
                        .maxInMemorySize(20 * 1024 * 1024))
                .build();
        long startTime = System.currentTimeMillis();
        log.info("requestAttachTest-开始下载Filed:{}",platformFileDto.getId());
        WebClient webClient = WebClient.create().mutate().exchangeStrategies(strategies).build();
        Resource resource = webClient.get().uri(
                propConfig.getPlatformCourseAttachmentPrefixDomain()+platformFileDto.getUrl())
                .retrieve().bodyToMono(Resource.class).block();
        attachmentFileDto.setResource(resource);
        log.info("requestAttachTest-结束下载Filed:{}-用时:{}",platformFileDto.getId(),(System.currentTimeMillis()-startTime)/1000);
        return attachmentFileDto;
    }

    /**
     *  校验参数
     * @param attachmentParam 参数
     */
    private void validate(FileAttachmentParam attachmentParam){
        LoginUser user = LoginUser.current();
        String fileIdStr = attachmentParam.getFileIds().stream().sorted().map(String::valueOf).collect(Collectors.joining());
        String checkSign = MD5Util.encryption(fileIdStr + user.getCompany()+attachmentParam.getType(),
                Commons.COURSE_ATTACHMENT_ENCRYPT);
        log.info("userId:[{}]-validate--fileIds:{}--sign:[{}]-checkSign:[{}]",user.getId(),attachmentParam.getFileIds(),
                attachmentParam,checkSign);
        if (!Objects.equals(checkSign,attachmentParam.getSign())){
            throw new AppClientException("请求参数不合法");
        }
    }
}

```